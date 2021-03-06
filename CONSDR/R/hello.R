# This is a function named 'condcor' and 'condsdr'

# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Install Package:           'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'

condcor<- function(x, y, z, trans=1, seed=1, h=10) {
  set.seed(1)
  library(nortest)
  library(MASS)
  library(splines)

  z <- as.matrix(z)
  n <- nrow(z); p1 <- ncol(z)
  x <- x - mean(x)
  z <- z - outer(rep(1, n), colMeans(z), "*")
  theta <- solve(t(z)%*%z) %*% (t(z)%*%x)

  # 转换函数为样条基函数
  if(trans == 1) {
    u <- t(bs(y, h))
    u <- u - outer(rowMeans(u), rep(1, ncol(u)), "*")
    # for (j in 1:nrow(u)) {
    #   u[j,] <- u[j,] - rowMeans(u)[j]
    # }
  }

  # 转换函数为y^k
  if(trans == 2) {
    u <- t(outer(y, 1:h, "^"))
    u <- u - outer(rowMeans(u), rep(1, ncol(u)), "*")
  }

  # 转换函数为fk(y)=y if y is in the kth slice
  if(trans == 3) {
    dis <- n/h
    u <- matrix(NA, h, n)
    for (ir in 1:h) {
      for (jr in 1:n) {
        u[ir,jr] <- ifelse(((ir-1)*dis)<jr & jr<(ir*dis+1), y[jr], 0)
      }
    }
    u <- u - outer(rowMeans(u), rep(1, ncol(u)), "*")
  }

  # 转换函数为fk(y)=1 if y is in the kth slice
  if(trans == 4){
    dis <- n/h
    u <- matrix(NA, h, n)
    for (ir in 1:h) {
      for (jr in 1:n) {
        u[ir,jr] <- ifelse(((ir-1)*dis)<jr & jr<(ir*dis+1), 1, 0)
      }
    }
    u <- u - outer(rowMeans(u), rep(1, ncol(u)), "*")
  }

  Gamma <- matrix(NA, p1, h)
  for (k in 1:h) {
    Gamma[,k] <- solve(t(z)%*%z)%*%(t(z)%*%u[k,])
  }
  u.tilde <- u - t(Gamma)%*%t(z)
  x.tilde <- x - t(theta)%*%t(z)

  cov_hat <- function(X, Y) {
    (X%*%t(Y))/n
  }

  varu.hat <- cov_hat(u.tilde, u.tilde)
  cov.hat <- cov_hat(u.tilde, x.tilde)
  rho2.hat <- (t(cov.hat)%*%ginv(varu.hat)%*%cov.hat)/var(t(x.tilde)) # ginv()广义逆

  lambda <- solve(eigen(varu.hat)$vectors)%*%(varu.hat)%*%(eigen(varu.hat)$vectors)
  lambda.sqrt <- diag(sqrt(diag(lambda)))
  Sigma.sqrt <- (eigen(varu.hat)$vectors)%*%lambda.sqrt%*%solve(eigen(varu.hat)$vectors)

  ux <- matrix(NA, h, n)
  for(i in 1:h){
    ux[i,] <- u.tilde[i,]*x.tilde
  }

  varux.hat <- matrix(NA, h, h)
  for(v in 1:h){
    for(s in 1:h){
      varux.hat[v,s] <- cov(ux[v,], ux[s,])
    }
  }
  Nsigma <- solve(Sigma.sqrt)%*%varux.hat%*%solve(Sigma.sqrt)/var(as.vector(x.tilde))

  num.rand <- 1000
  randmat <- mvrnorm(num.rand, rep(0,h), Nsigma)
  t0 <- rowSums(randmat^2)
  t0 <- sort(t0)
  resu <- n*rho2.hat > t0[num.rand*0.95]

  if(resu) {
    res.list <- list(rho2.hat=rho2.hat, test.result="x and y is conditional dependent")
  } else {
    res.list <- list(rho2.hat=rho2.hat, test.result="x and y is conditional independent")
  }
  return(res.list)
}

condsdr <- function(X, y, trans=1, seed=1, h=10){
  p <- ncol(X)
  rho <- c()
  for(v in 1:p){
    x <- X[,v]; z <- X[,-v]
    rho[v] <- condcor(x, y, z, trans, seed, h)$rho2.hat
  }

  stat <- rho[order(rho, decreasing=TRUE)]

  rr <- rep(0, p-1)
  for(i in 1:(p-1)){
    rr[i] <- stat[i]/stat[i+1]
  }

  qhat <- which.max(rr)
  R <- order(rho, decreasing=TRUE)[1:qhat]
  selvar <- paste0("var", R)
  res <- data.frame(selectvar=selvar, rho2=rho[R])
  return(res)
}

