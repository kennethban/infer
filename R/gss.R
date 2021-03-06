#' Subset of data from the General Social Survey (GSS).
#' 
#' The General Social Survey is a high-quality survey which gathers data on 
#' American society and opinions, conducted since 1972. This data set is a 
#' sample of 3,000 entries from the GSS, including demographic markers and some 
#' economic variables. Note that this data is included for demonstration only, 
#' and will not provide accurate estimates relating to GSS variables unless 
#' properly weighted. However, due to the high quality of the GSS, the 
#' unweighted data will approximate the weighted data in some analyses.
#' @format A tibble with 3000 rows and 11 variables:
#' \describe{
#'   \item{year}{year respondent was surveyed}
#'   \item{age}{age at time of survey, truncated at 89}
#'   \item{sex}{respondent's sex}
#'   \item{college}{whether on not respondent has a college degree, including 
#'   junior/community college}
#'   \item{partyid}{political party affiliation}
#'   \item{hompop}{number of persons in household}
#'   \item{hours}{number of hours worked in week before survey, truncated at 89}
#'   \item{income}{total family income}
#'   \item{class}{subjective socioeconomic class identification}
#'   \item{finrela}{opinion of family income}
#'   \item{weight}{survey weight}
#' }
#' @source \url{https://gss.norc.org}
"gss"
