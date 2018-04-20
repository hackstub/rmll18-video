require 'json'
require 'yaml'
require 'date'
#YAML.load_file(Date.today.strftime("%Y")+".yml")
program = YAML.load_file("2017.yml")

# program.each do |current_day|
#     puts current_day
# end

# program.each {|key, value| puts "#{key} is #{value}" }
# puts program.select
# program[Date.parse("2017-06-29")]["talks"].each {
#     |e| if DateTime.strptime(e["from"],'%H:%M')>DateTime.now
#         puts e["title"]
#     end
# }
$result = {"prog" => [ program[Date.parse("2017-06-29")]["talks"][0]["title"] + " - " + program[Date.parse("2017-06-29")]["talks"][0]["author"] ]}
program[Date.parse("2017-06-29")]["talks"].each do |e|
    if DateTime.strptime(e["to"],'%H:%M') < DateTime.strptime('15:00','%H:%M')
        $result = {"prog" => [e["title"] + " - " + e["author"]]}
    end
    if DateTime.strptime(e["from"],'%H:%M') >= DateTime.strptime('15:00','%H:%M')
        $result["prog"].push(e["title"] + " - " + e["author"])
    end
end

# { prog: y[Date.parse('2017-06-29')]['talks'].collect { |t| "#{t['title']} #{t['author']} à #{t['from']}" } }

source = File.open('index.html',"r")
render = File.open('index2.html',"r+")
for i in [0..31] do
    render.write(source.each_line.to_a[i])
end
render.write(source.each_line.to_a[0..31][0].to_s + '\n')
render.write('								<h3 id="p0">' + $result['prog'][0] + '</h3>')
render.write(source.each_line.to_a[33..93])
render.close
for i in 1..4 do
    puts $result["prog"][i]
end

# puts program[Date.parse("2017-06-29")]["talks"][1]["author"]
