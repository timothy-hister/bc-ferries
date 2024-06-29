pacman::p_load(RSelenium)

setup_remote = function() {
  driver = RSelenium::rsDriver(browser='chrome', chromever = 'latest', geckover = NULL, iedrver = NULL, phantomver = NULL)
  driver[['client']]
}
