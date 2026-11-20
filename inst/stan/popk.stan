// Population PK model with closed-form 1- and 2-compartment solutions.
// Doses are superposed; no ODE solver is used.
functions {
  // Log likelihood of one observation. y is DV (log DV for err == 4). With
  // cens == 1, y is the quantification limit and the observation lies below
  // it (Beal's M3 method).
  real obs_lpdf(real y, real c, vector sigma, int err, int cens) {
    real mu = err == 4 ? log(c) : c;
    real sd_y;
    if (err == 1 || err == 4) sd_y = sigma[1];
    else if (err == 2) sd_y = sigma[1] * c;
    else sd_y = sqrt(square(sigma[1]) + square(sigma[2] * c));
    if (cens == 1) return normal_lcdf(y | mu, sd_y);
    return normal_lpdf(y | mu, sd_y);
  }

  // Orthonormal Helmert basis applied to u (length N - 1): returns a length-N
  // vector that sums to zero. With u ~ N(0, I), the result is z - mean(z) for
  // z ~ N(0, I). O(N).
  row_vector helmert(row_vector u, int N) {
    row_vector[N] out;
    real tail = 0;
    for (jj in 1:N) {
      int j = N + 1 - jj;
      if (j <= N - 1) tail += u[j] / sqrt(j * (j + 1.0));
      out[j] = tail;
      if (j > 1) out[j] -= (j - 1) * u[j - 1] / sqrt((j - 1) * (j + 0.0));
    }
    return out;
  }

  // Integral of exp(-ka * s) * exp(-k * (tau - s)) over s in [0, tau].
  real absorption_kernel(real tau, real k, real ka) {
    real x = (ka - k) * tau;
    if (abs(x) < 1e-5)
      return tau * exp(-(k + ka) * tau / 2) * (1 + square(x) / 24);
    return tau * exp(-fmin(k, ka) * tau) * (-expm1(-abs(x)) / abs(x));
  }
  // Central concentration at time tau after one dose.
  // par: [CL, V, KA] (ncmt = 1) or [CL, V1, Q, V2, KA] (ncmt = 2); KA used only if oral.
  // Disposition after a unit bolus: a[1] exp(-l[1] t) + a[2] exp(-l[2] t).
  // Returns [l1, l2, a1, a2] (1-cmt: a2 = 0).
  vector disposition(vector par, int ncmt) {
    vector[4] out;
    if (ncmt == 1) {
      out[1] = par[1] / par[2];
      out[2] = 1;
      out[3] = 1 / par[2];
      out[4] = 0;
    } else {
      real v1 = par[2];
      real k10 = par[1] / v1;
      real k12 = par[3] / v1;
      real k21 = par[3] / par[4];
      real s = k10 + k12 + k21;
      real disc = sqrt(square(s) - 4 * k10 * k21);
      real alpha = (s + disc) / 2;
      real beta = (s - disc) / 2;
      out[1] = alpha;
      out[2] = beta;
      out[3] = (alpha - k21) / (alpha - beta) / v1;
      out[4] = (k21 - beta) / (alpha - beta) / v1;
    }
    return out;
  }

  // exp(-l t) summed over a dose every ii: exp(-l t) / (1 - exp(-l ii)).
  real geo(real l, real t, real ii) {
    return exp(-l * t) / (-expm1(-l * ii));
  }

  // d geo / d l, for KA equal to a disposition rate.
  real geo_dl(real l, real t, real ii) {
    real q = -expm1(-l * ii);
    return (-t * exp(-l * t) * q - exp(-l * t) * ii * exp(-l * ii)) / square(q);
  }

  // Concentration at time t >= 0 after a steady-state dose (SS = 1) given
  // every ii: the sum of single-dose concentrations at t, t + ii, t + 2 ii, ...
  real ss_conc(real t, real amt, real rate, real ii, vector par, int ncmt, int oral) {
    vector[4] d = disposition(par, ncmt);
    int nterm = ncmt == 1 ? 1 : 2;
    real c = 0;
    for (j in 1:nterm) {
      real l = d[j];
      real a = d[j + 2];
      if (oral == 1) {
        real ka = par[ncmt == 1 ? 3 : 5];
        if (abs(ka - l) < 1e-6 * l) c += amt * ka * a * (-geo_dl(l, t, ii));
        else c += amt * ka * a / (ka - l) * (geo(l, t, ii) - geo(ka, t, ii));
      } else if (rate > 0) {
        real dur = amt / rate;
        if (t < dur)
          c += rate * a / l * (-expm1(-l * t) + (-expm1(-l * dur)) * geo(l, t + ii - dur, ii));
        else
          c += rate * a / l * (-expm1(-l * dur)) * geo(l, t - dur, ii);
      } else {
        c += amt * a * geo(l, t, ii);
      }
    }
    return c;
  }

  // Contribution of one dose record at time tau after it. ii > 0 marks a
  // steady-state dose; before it (-ii < tau < 0) the same dose train applies.
  real dose_contrib(real tau, real amt, real rate, real ii, vector par, int ncmt, int oral) {
    if (ii > 0) {
      if (tau >= 0) return ss_conc(tau, amt, rate, ii, par, ncmt, oral);
      if (tau > -ii) return ss_conc(tau + ii, amt, rate, ii, par, ncmt, oral);
      return 0;
    }
    return dose_conc(tau, amt, rate, par, ncmt, oral);
  }

  real dose_conc(real tau, real amt, real rate, vector par, int ncmt, int oral) {
    if (tau < 0) return 0;
    if (ncmt == 1) {
      real cl = par[1];
      real v = par[2];
      real k = cl / v;
      if (oral == 1) {
        real ka = par[3];
        return amt * ka / v * absorption_kernel(tau, k, ka);
      }
      if (rate > 0) {
        real dur = amt / rate;
        if (tau <= dur) return rate / cl * (1 - exp(-k * tau));
        return rate / cl * (1 - exp(-k * dur)) * exp(-k * (tau - dur));
      }
      return amt / v * exp(-k * tau);
    } else {
      real v1 = par[2];
      real k10 = par[1] / v1;
      real k12 = par[3] / v1;
      real k21 = par[3] / par[4];
      real s = k10 + k12 + k21;
      real disc = sqrt(square(s) - 4 * k10 * k21);
      real alpha = (s + disc) / 2;
      real beta = (s - disc) / 2;
      real a = (alpha - k21) / (alpha - beta);
      real b = (k21 - beta) / (alpha - beta);
      if (oral == 1) {
        real ka = par[5];
        return amt * ka / v1 * (a * absorption_kernel(tau, alpha, ka)
                               + b * absorption_kernel(tau, beta, ka));
      }
      if (rate > 0) {
        real dur = amt / rate;
        if (tau <= dur)
          return rate / v1 * (a / alpha * (1 - exp(-alpha * tau)) + b / beta * (1 - exp(-beta * tau)));
        return rate / v1 * (a / alpha * (1 - exp(-alpha * dur)) * exp(-alpha * (tau - dur))
                            + b / beta * (1 - exp(-beta * dur)) * exp(-beta * (tau - dur)));
      }
      return amt / v1 * (a * exp(-alpha * tau) + b * exp(-beta * tau));
    }
  }
}
data {
  int<lower=1> N;                       // subjects
  int<lower=1, upper=2> ncmt;
  int<lower=0, upper=1> oral;
  int<lower=2> K;                       // structural parameters
  int<lower=1> n_obs;
  array[n_obs] int<lower=1, upper=N> obs_id;
  vector[n_obs] obs_time;
  vector[n_obs] dv;
  int<lower=1> n_dose;
  vector[n_dose] dose_time;
  vector<lower=0>[n_dose] dose_amt;
  vector<lower=0>[n_dose] dose_rate;    // 0 = bolus or oral
  vector<lower=0>[n_dose] dose_ii;      // > 0: steady-state dose (SS = 1) given every dose_ii
  array[N] int<lower=1> dose_start;
  array[N] int<lower=0> dose_end;       // dose_end < dose_start: no dose
  int<lower=0> n_eta;
  array[n_eta] int<lower=1, upper=K> eta_par;
  int<lower=0, upper=1> corr;
  int<lower=0> n_beta;
  array[n_beta] int<lower=1, upper=K> beta_par;
  matrix[N, n_beta] xbeta;              // covariate terms on the log scale
  matrix[N, K] cov_offset;                  // fixed covariate effects on the log scale
  int<lower=1, upper=4> err;            // 1 additive, 2 proportional, 3 combined, 4 additive on log scale
  vector[K] prior_theta_mu;             // log scale
  vector<lower=0>[K] prior_theta_sd;
  vector[n_beta] prior_beta_mu;
  vector<lower=0>[n_beta] prior_beta_sd;
  vector<lower=0>[n_eta] prior_omega_sd; // half-normal scale
  real<lower=0> prior_lkj;
  vector<lower=0>[2] prior_sigma_sd;    // half-normal scales: [additive or log, proportional]
  int<lower=0, upper=1> prior_only;
  array[n_obs] int<lower=0, upper=1> cens;   // 1: DV is the LLOQ and the value is below it
  int<lower=0, upper=1> ka_fast;       // 1: typical KA > typical disposition rate (oral only)
  array[n_eta] int<lower=0, upper=1> decouple;  // 1: sample typical value + mean random effect
}
transformed data {
  int n_sigma = err == 3 ? 2 : 1;
  vector[n_obs] y = err == 4 ? log(dv) : dv;
}
parameters {
  // mu_raw: for parameters with IIV, the log typical value plus the mean
  // random effect of the sample (well identified; removes the strong
  // posterior correlation between typical value and mean eta). For KA with
  // ka_fast, log(KA - rate) as before. Other parameters: log typical value.
  vector[K] mu_raw;
  vector[n_beta] beta;
  vector<lower=0>[n_eta] omega;
  cholesky_factor_corr[corr == 1 ? n_eta : 0] L_corr;
  vector[n_eta] zbar;                  // mean of the standardised random effects
  matrix[n_eta, N - 1] u;              // deviations from that mean (Helmert coordinates)
  vector<lower=0>[n_sigma] sigma;
}
transformed parameters {
  vector[K] theta_raw = mu_raw;        // log typical values (KA: log(KA - rate) with ka_fast)
  {
    matrix[n_eta, n_eta] L_omega = corr == 1 ? diag_pre_multiply(omega, L_corr) : diag_matrix(omega);
    vector[n_eta] shift = L_omega * zbar;
    for (e in 1:n_eta)
      if (decouple[e] == 1 && !(ka_fast == 1 && eta_par[e] == K)) theta_raw[eta_par[e]] -= shift[e];
  }
  vector[K] log_theta = theta_raw;
  real log_jac = 0;
  if (ka_fast == 1) {
    // fastest disposition rate of the reference subject: k (1-cmt) or alpha (2-cmt)
    vector[K] th = exp(theta_raw);
    real rate;
    if (ncmt == 1) rate = th[1] / th[2];
    else {
      real k10 = th[1] / th[2];
      real k12 = th[3] / th[2];
      real k21 = th[3] / th[4];
      real s = k10 + k12 + k21;
      rate = (s + sqrt(square(s) - 4 * k10 * k21)) / 2;
    }
    log_theta[K] = log(rate + th[K]);
    log_jac = theta_raw[K] - log_theta[K];   // d log_theta[K] / d theta_raw[K]
  }
  matrix[N, K] log_par = rep_matrix(log_theta', N) + cov_offset;
  real lprior = 0;
  {
    matrix[n_eta, n_eta] L_omega = corr == 1 ? diag_pre_multiply(omega, L_corr) : diag_matrix(omega);
    matrix[n_eta, N] z;
    for (e in 1:n_eta) z[e] = zbar[e] + helmert(u[e], N);
    matrix[n_eta, N] eta = L_omega * z;
    for (j in 1:n_beta) log_par[, beta_par[j]] += beta[j] * xbeta[, j];
    for (e in 1:n_eta) log_par[, eta_par[e]] += eta[e]';
  }
  lprior += normal_lpdf(log_theta | prior_theta_mu, prior_theta_sd);
  lprior += log_jac;   // keeps the stated prior on KA (truncated to KA > rate)
  lprior += normal_lpdf(beta | prior_beta_mu, prior_beta_sd);
  lprior += normal_lpdf(omega | 0, prior_omega_sd);
  if (corr == 1) lprior += lkj_corr_cholesky_lpdf(L_corr | prior_lkj);
  if (err == 1 || err == 4) lprior += normal_lpdf(sigma[1] | 0, prior_sigma_sd[1]);
  if (err == 2) lprior += normal_lpdf(sigma[1] | 0, prior_sigma_sd[2]);
  if (err == 3) lprior += normal_lpdf(sigma | 0, prior_sigma_sd);
}
model {
  target += lprior;
  // equivalent to to_vector(z) ~ std_normal()
  zbar ~ normal(0, inv_sqrt(N));
  to_vector(u) ~ std_normal();
  if (prior_only == 0) {
    for (n in 1:n_obs) {
      int i = obs_id[n];
      vector[K] par = exp(log_par[i]');
      real c = 0;
      for (d in dose_start[i]:dose_end[i])
        c += dose_contrib(obs_time[n] - dose_time[d], dose_amt[d], dose_rate[d], dose_ii[d], par, ncmt, oral);
      target += obs_lpdf(y[n] | c, sigma, err, cens[n]);
    }
  }
}
generated quantities {
  vector[n_obs] log_lik;
  for (n in 1:n_obs) {
    int i = obs_id[n];
    vector[K] par = exp(log_par[i]');
    real c = 0;
    for (d in dose_start[i]:dose_end[i])
      c += dose_contrib(obs_time[n] - dose_time[d], dose_amt[d], dose_rate[d], dose_ii[d], par, ncmt, oral);
    log_lik[n] = obs_lpdf(y[n] | c, sigma, err, cens[n]);
  }
}
