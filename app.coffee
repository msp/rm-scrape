# Thx to: http://nodeexamples.com/2013/05/21/scraping-webpages-using-zombie-js/
fs = require("fs")
assert = require("assert");
Browser = require("zombie")

###
Extracts the country information from the specified page.
@param {String} country url
@param {Function} callback The function to call when the data is loaded and parsed.
###
scrape = (url, callback) ->
  console.log("##################################")
  console.log(url)
  console.log("##################################")

  browser = new Browser

  extractNode = (obj, label) ->
    re = new RegExp("^" + label, "i")
    browser.text(obj).replace(re, "").trim()

  getTitle = (obj) ->
    extractNode obj, "Session Title:"

  extractListFor = (label, els) ->
    console.log("#### #{label} ####")
    collection = []

    browser.queryAll("li", els).map((el) ->
      console.log("LI: #{browser.text(el)}")
      collection.push browser.text(el)
    )

    return collection

  pageLoaded = (window) ->
    return window.document.querySelector(".cms-page")

  browser.visit(url, debug: false, runScripts: false, maxWait: 10, waitFor: 2).then(->
    browser.wait pageLoaded, ->
      context = browser.query(".cms-page");

      nodes = browser.queryAll(".cms-page").map((node) ->
        title = browser.text(node)
        country =  browser.text(browser.query("h2", context))
        intro = ""

        pTags = browser.queryAll("p", context)
        pTags.pop()  #we don't want the last para
        pTags.map((el) ->
          intro += browser.text(el)
        )

        ulTags = browser.queryAll("ul", context)
        console.log("UL tags: #{ulTags.length}")

        switch ulTags.length
          when 2
            highlights = extractListFor("highlights", ulTags[0])
            social = extractListFor("social", ulTags[1])
          else
            highlights = extractListFor("highlights", ulTags[0])
            uses = extractListFor("uses", ulTags[1])
            social = extractListFor("social", ulTags[2])

        country: country
        intro: intro
        highlights: highlights
        uses: uses
        social: social
      )

      callback nodes
      return
  ).fail (error) ->
    console.error "Transport error", error
    return

JURISDICTIONS = [
  "belize"
  "british-anguilla-2"
  "british-virgin-islands"
  "costa-rica"
  "cyprus-2"
  "hong-kong"
  "malta-2"
  "nevada-ee-uu"
  "new-zealand"
  "republic-panama"
  "samoa-2"
  "seychelles-2"
  "bahamas"
  "netherlands"
  "united-kingdom"
  "wyoming-2"
]

JURISDICTIONS.forEach((element, index, array) ->
  scrape "http://www.mossackfonseca.com/service/#{element}/", (data) ->
    jsonStr = JSON.stringify(data, null, "  ")
    fs.writeFile "#{element}.json", jsonStr
    return
)
