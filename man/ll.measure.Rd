% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/measureFunctions.R
\name{ll.measure}
\alias{ll.measure}
\title{Negative log-likelihood}
\usage{
ll.measure(model, data, sd)
}
\arguments{
\item{model}{numerics not associated with (mean, standard deviation) pairs, likely model results}

\item{data}{numerics mean associated with (mean, standard deviation) pairs, likely data results}

\item{sd}{numerics standard deviation (normal) associated with (mean, standard deviation) pairs, likely data results}
}
\value{
a numeric scalar 2 times the sum of, the difference between the model and data, squared, divided by the standard deviation. \eqn{2 \sum{(\frac{m-d}/{s})^2}}
}
\description{
Calculate the negative log likelihood for model results compaired to paired data mean and normal standard deviation.
}

