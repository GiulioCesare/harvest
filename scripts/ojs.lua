-- Commented by Argentino 21/08/2019
wget.callbacks.get_urls = function(file, url, is_css, iri)

  -- table of added urls that we want downloaded
  local urls = {}

  -- if url contains "article/download"
  if string.match(url, "article/download") then
      -- create an analogue view url
      view_url = string.gsub(url, "download", "view")

      -- add the view url to the urls table
      table.insert(urls, { url=view_url })
  end
  -- return the table with added urls (if any)
  return urls
end
