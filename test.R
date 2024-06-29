pacman::p_load(RSelenium)

setup_remote = function() {
  driver = tryCatch(
    RSelenium::rsDriver(browser='chrome', chromever = 'latest', geckover = NULL, iedrver = NULL, phantomver = NULL), error = function(e) RSelenium::rsDriver(browser='firefox', chromever = NULL, geckover = 'latest', iedrver = NULL, phantomver = NULL), error = function(e) RSelenium::rsDriver(browser='internet explorer', chromever = NULL, geckover = 'latest', iedrver = 'latest', phantomver = NULL), error = function(e) e)
  driver[['client']]
}

