# Fetch the official party register and writes parsed data into 'partidos.csv'.

# Argh, the official web site seems to be rejecting connections from Morph.io...

require 'mechanize'
require 'csv'

agent = Mechanize.new

1.upto(6000) do |id|
  puts "Fetching party #{id}..."

  # Read index page, just so the id is set in the session (who makes these websites?!)
  agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/partido_politicoDatos.html?nmformacion=#{id}")

  # Now we can get the page with the actual info, which now will have the party details
  begin
    page = agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/recurso/partido_politicoDetalle.html")
    File.open("staging/#{id}.html", 'w') {|f| f.write(page.content) }
  rescue Mechanize::ResponseCodeError => e
    puts "Ignoring #{id}: #{e}"
  end

end
