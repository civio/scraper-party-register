# Fetch the official party register and writes parsed data into 'partidos.csv'.

# Argh, the official web site seems to be rejecting connections from Morph.io...

require 'mechanize'
require 'csv'

# Allow overriding of starting id from command line
# Alternatively, we could skip existing files, unless a --force option is given in the command line
start_id = ARGV[0] ? ARGV[0].to_i : 1

agent = Mechanize.new

start_id.upto(6000) do |id|
  puts "Fetching party #{id}..."

  # Read index page, just so the id is set in the session (who makes these websites?!)
  begin
    agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/partido_politicoDatos.html?nmformacion=#{id}")
  rescue Errno::ETIMEDOUT, Timeout::Error
    puts "Timeout #{id}. Retrying..."
    sleep 5
    retry
  end

  # Now we can get the page with the actual info, which now will have the party details
  begin
    @page = agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/recurso/partido_politicoDetalle.html")
    File.open("staging/#{id}.html", 'w') {|f| f.write(@page.content) }
  rescue Mechanize::ResponseCodeError => e
    puts "Ignoring #{id}: #{e}"
  rescue Errno::ETIMEDOUT, Timeout::Error
    puts "Timeout #{id}. Retrying..."
    sleep 5
    retry
  end

  # Download the associated picture, if available
  # XXX: We assume that they are all in JPEG format (".jpg" extension), seems to work.
  next if @page.search('#simbolo').empty?
  begin
    picture = agent.get("http://servicio.mir.es/nfrontal/webpartido_politico/recurso/webpartido_politico/recurso/descargarImagen.html")
    picture.save("pictures/#{id}.jpg")
  rescue Mechanize::ResponseCodeError => e
    puts "Ignoring #{id}: #{e}"
  rescue Errno::ETIMEDOUT, Timeout::Error
    puts "Timeout #{id}. Retrying..."
    sleep 5
    retry
  end

  sleep 2
end
