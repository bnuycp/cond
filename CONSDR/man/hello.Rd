\name{CONSDR}
\alias{hello}
\title{Hello, World!}
\usage{
condcor()
condsdr()
}
\description{
 Introduction:
 Code of a new partial correlation coefficient
 condcor:
 input: x, y, z, which x and y is univariate variable, and z can be univariate or multivariate.
 output: the partial correlation coefficient of x and y given z, ie. \rho^2(x,y|z).
 condsdr:
 input: Design matrix X, response y.
 output: the variable selected.
}
\examples{
n <- 200; p <- 10; rho <- 0.5
sigma <- toeplitz(rho^seq(0, p-1))
X <- mvrnorm(n, mu=rep(0, p), sigma)
error <- rnorm(n)
y <- X[,1] + X[,2] + error
condsdr(X, y, trans=1, seed=1, h=10)
x <- X[,1]; z <- X[,-1]
condcor(x, y, z, trans=1, seed=1, h=10)
}
