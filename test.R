pacman::p_load(RSelenium)

setup_remote = function() {
  driver = RSelenium::rsDriver(browser="firefox", chromever = NULL, geckover = "latest", iedrver = NULL, phantomver = NULL)
  driver[['client']]
}
