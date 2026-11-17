// Population PK model with closed-form 1- and 2-compartment solutions.
// Doses are superposed; no ODE solver is used.
functions {
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
  int<lower=0, upper=1> ka_fast;       // 1: typical KA > typical disposition rate (oral only)
}
transformed data {
  int n_sigma = err == 3 ? 2 : 1;
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
      if (!(ka_fast == 1 && eta_par[e] == K)) theta_raw[eta_par[e]] -= shift[e];
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
        c += dose_conc(obs_time[n] - dose_time[d], dose_amt[d], dose_rate[d], par, ncmt, oral);
      if (err == 4) dv[n] ~ normal(log(c), sigma[1]);
      else if (err == 1) dv[n] ~ normal(c, sigma[1]);
      else if (err == 2) dv[n] ~ normal(c, sigma[1] * c);
      else dv[n] ~ normal(c, sqrt(square(sigma[1]) + square(sigma[2] * c)));
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
      c += dose_conc(obs_time[n] - dose_time[d], dose_amt[d], dose_rate[d], par, ncmt, oral);
    if (err == 4) log_lik[n] = normal_lpdf(dv[n] | log(c), sigma[1]);
    else if (err == 1) log_lik[n] = normal_lpdf(dv[n] | c, sigma[1]);
    else if (err == 2) log_lik[n] = normal_lpdf(dv[n] | c, sigma[1] * c);
    else log_lik[n] = normal_lpdf(dv[n] | c, sqrt(square(sigma[1]) + square(sigma[2] * c)));
  }
}
