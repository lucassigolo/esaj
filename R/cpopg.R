
#' @title Download first degree lawsuits filed in Brazilian Justice Courts
#'
#' @description
#' This function downloads lawsuits as HTMLs. Given a lawsuit ID, and
#' the path to a directory it will collect the lawsuit, and save it to
#' the provided directory.
#'
#' @section About lawsuits:
#' The lawsuits contemplated by this funtion have to be filed in a
#' Brazilian Tribunal de Justica (Justice Court). [download_cpopg()]
#' finds the lawsuit in its state's online Sistema de Automacao de Justica
#' (Justice Automation System), solves the captcha withholding the
#' information, and collects the HTML.
#'
#' @section Implemented TJs:
#' Unfortunatelly [download_cpopg()] doesn't yet work with all 27 TJs in
#' Brazil. Here are the ones already implemented:
#' \itemize{
#'   \item TJAM (Amazonas)
#'   \item TJAL (Alagoas)
#'   \item TJBA (Bahia)
#'   \item TJSC (Santa Catarina)
#'   \item TJSP (Sao Paulo)
#' }
#'
#' @param id A character vector of one or more lawsuit IDs
#' @param path Path to the directory where the lawsuit should be saved
#' @return A character vector with the path to the downloaded lawsuit
#'
#' @export
download_cpopg <- function(id, path = ".") {

  # Normalize path
  dir.create(path, FALSE, TRUE)
  path <- normalizePath(path) %>%
    stringr::str_c("/")

  # Strip ID down
  id <- stringr::str_replace_all(id, "[^0-9]", "")
  if (any(stringr::str_length(id) != 20)) { stop("Invalid ID") }

  # Iterate over IDs
  download_cpopg_ <- purrr::possibly(download_cpopg_, "")
  pb <- progress::progress_bar$new(
    "Downloading [:bar] :percent eta: :eta", length(id))
  downloaded <- c()
  for (i in seq_along(id)) {
    downloaded <- append(downloaded, download_cpopg_(id[i], path))
    pb$tick()
  }

  return(downloaded)
}

# Download one lawsuit
download_cpopg_ <- function(id, path) {

  # Choose appropriate download function
  if (get_n(id) %in% c("05")) { download <- download_bw_lawsuit }
  else if (get_n(id) %in% c("02", "26")) { download <- download_noc_lawsuit }
  else { download <- download_rgb_lawsuit }

  # Get URLs for the download
  data <- get_lwst_data(id)

  # If file exists, return it without downloading
  if (file.exists(stringr::str_c(path, id, ".html"))) {
    return(stringr::str_c(path, id, ".html"))
  }

  # Download lawsuit
  download(id, path, data$u_captcha, data$u_search, cpopg_query(id))
}
