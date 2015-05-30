# Parse the official party register and writes parsed data into 'partidos.csv'.
# (I tend to output to terminal, but in this case it's good to have progress updates there,
# plus some fields are too big to make sense on the terminal.)

# Argh, the official web site seems to be rejecting connections from Morph.io...

require 'nokogiri'
require 'csv'

def getField(page, field)
  page.search(field).text.strip
end

def getHeadingContent(heading)
  # Try the next DOM element
  content = heading.next.content.strip

  # Sometimes it's a new line, so we pick the next one
  # TODO: Shall we keep going? I don't know
  content = heading.next.next.content.strip if content.empty?

  content
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
  # Read pre-fetched page
  puts "Parsing party #{id}..."
  begin
    input = File.open("staging/#{id}.html")
  rescue Errno::ENOENT => e
    puts "Skipping #{id}: file not found"
    next
  end
  page = Nokogiri::HTML(input)

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
  roles = []
  page.search('#promotor').each do |leader|
    role = leader.previous.content
    roles << { role: role, name: leader.content.strip }
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
      party_scope = getHeadingContent(heading)
      next
    end

    if heading_text =~ /Denominaciones Múltiples/
      other_names = getHeadingContent(heading)
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
