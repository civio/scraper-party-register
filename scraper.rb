# Parse the official party register and writes parsed data into 'partidos.csv'.
# (I tend to output to terminal, but in this case it's good to have progress updates there.)

# Argh, the official web site seems to be rejecting connections from Morph.io...

require 'mechanize'
require 'csv'

agent = Mechanize.new

def getField(page, field)
  page.search(field).text.strip
end

party_data = CSV.open('partidos.csv', "w")
party_data << [
    "id",
    "party_type",
    "short_name",
    "name",
    "register_date",
    "address",
    "town",
    "region",
    "phone_number",
    "phone_number_extra",
    "fax_number",
    "email",
    "web",
    "comments",
    "party_scope",
    "roles",
    "other_names"
  ]

1.upto(6000) do |id|
  puts "Fetching party #{id}..."

  # Read index page, just so the id is set in the session (who makes these websites?!)
  agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/partido_politicoDatos.html?nmformacion=#{id}")

  # Now we can get the page with the actual info, which now will have the party details
  page = agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/recurso/partido_politicoDetalle.html")

  # Parse the page
  party_type = getField(page, "#tipoFormacion")
  if party_type.empty?   # We got an empty page, skip
    puts "Skipping"
    next
  end

  short_name = getField(page, "#siglas")
  name = getField(page, "#nombre")
  register_date = getField(page, "#fecInscripcion")
  address = getField(page, "#domicilioSocial")
  town = getField(page, "#poblacion").gsub(/[\n\t]+/, '')
  region = getField(page, "#autonomia")
  phone_number = getField(page, "#telefono1")
  phone_number_extra = getField(page, "#telefono2")
  fax_number = getField(page, "#fax")
  email = getField(page, "#email")
  web = getField(page, "#paginaweb")
  comments = getField(page, "#observaciones")

  # FIXME: Pictures are tricky
  # picture = page.search("#simbolo img")[0]
  # if picture

  # Retrieve party leaders: there are a variable number of fields, and some of them
  # appear multiple times
  roles = {}
  page.search('#promotor').each do |leader|
    role = leader.previous.content
    roles[role] = leader.content.strip
  end

  # Getting the scope of the party or previous names is horrifying,
  # we have to use the h1 headings to navigate around the page *sigh*
  headings = page.search('h1')
  party_scope = ''
  other_names = ''
  headings.each do |heading|
    heading_text = heading.content.strip

    next if heading_text =~ /Información/                  # We've got that already
    next if heading_text =~ /Representantes Legales/       # ...

    if heading_text =~ /Ámbito Territorial/
      party_scope = heading.next.next.content.strip   # *sigh*
      next
    end

    if heading_text =~ /Denominaciones Múltiples/
      other_names = heading.next.next.content.strip   # *sigh*
      next
    end

    # If we get here it means there's a type of heading we don't know about
    puts "WARNING: Unexpected heading ('#{heading_text}') found for party #{id}"
  end


  # Output results
  party_data << [
      id,
      party_type,
      short_name,
      name,
      register_date,
      address,
      town,
      region,
      phone_number,
      phone_number_extra,
      fax_number,
      email,
      web,
      comments,
      party_scope,
      roles,
      other_names
    ]
end
