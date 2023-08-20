# Central Coast Charities Scraper

Scrapes the [Australian Charities and Non-for-profits Commission](https://acnc.gov.au/) website for registered charities on the [NSW Central Coast](https://en.wikipedia.org/wiki/Central_Coast_(New_South_Wales)).

> **Note**
>
> If you just want the scraped data, [download the SQLite database](https://github.com/auxesis/central_coast_charities_scraper/releases/tag/scraper).

## Quickstart

To run locally:

``` bash
# Clone the repo
git clone https://github.com/auxesis/central_coast_charities_scraper
cd central_coast_charities_scraper

# Install dependencies
bundle

# Run the scraper
bundle exec ruby scraper.rb

# Query the data
sqlite3 data.sqlite 'select count(*) from charities'
```
