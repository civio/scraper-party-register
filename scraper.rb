# Argh, the official web site seems to be rejecting connections from Morph.io...

require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

def getField(page, field)
  page.search(field).text.strip
end

4198.upto(4199) do |id|
  puts "Fetching party #{id}..."

  # Read index page, just so the id is set in the session (who makes these websites?!)
  agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/partido_politicoDatos.html?nmformacion=#{id}")

  # Now we can get the page with the actual info, which now will have the party details
  page = agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/recurso/partido_politicoDetalle.html")

  # Parse the page
  data = {}
  data["id"] = id
  data["party_type"] = getField(page, "#tipoFormacion")
  data["short_name"] = getField(page, "#siglas")
  data["name"] = getField(page, "#nombre")
  data["register_date"] = getField(page, "#fecInscripcion")
  data["address"] = getField(page, "#domicilioSocial")
  data["town"] = getField(page, "#poblacion")
  data["region"] = getField(page, "#autonomia")
  data["phone_number"] = getField(page, "#telefono1")
  data["phone_number_extra"] = getField(page, "#telefono2")
  data["fax_number"] = getField(page, "#fax")
  data["email"] = getField(page, "#email")
  data["web"] = getField(page, "#paginaweb")

  # FIXME: Pictures are tricky
  # picture = page.search("#simbolo img")[0]
  # if picture

  # Write out to the sqlite database using scraperwiki library
  ScraperWiki.save_sqlite(["id"], data)
end
