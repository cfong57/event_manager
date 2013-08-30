require "csv"
require "sunlight/congress"
require "erb"
require "date"

#registered for my own key since it seems like a neat api
Sunlight::Congress.api_key = "d9eef93ff85044a09c2db5242de5588c"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phonenumber(phonenumber)
  clean = 0000000000
  phonenumber.to_s.gsub!(/\D/, "") #eliminate anything that isn't a number
  nums = phonenumber.length

  #not the cleanest logic but it works
  #skip this if it's a bad number
  unless (nums < 10 or nums > 11 or ((nums == 11) and (phonenumber[0] != 1)))
    #get the desired 10 digits
    nums == 11 ? clean = phonenumber[1..10] : clean = phonenumber
  end
  return clean
end

def get_reghour(date)
   DateTime.strptime(date, "%m/%d/%y %k:%M").hour #military time
end

#pretty sure there should be something in date/time/datetime that makes this unnecessary...
#global in scope because no sense recreating it every time to_day is called
$num_to_day = {0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday",
5 => "Friday", 6 => "Saturday"}

def to_day(num)
  num.between?(0, 6) ? $num_to_day[num] : "ERROR"
end

def get_regday(date)
   to_day(DateTime.strptime(date, "%m/%d/%y %k:%M").wday)
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")
  filename = "output/thanks_#{id}.html"
  File.open(filename, "w") {|file| file.puts form_letter }
end

puts "EventManager initialized."

contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new(template_letter)

#"Sunday" => [5, 13, 21], "Monday" => [3, 6]...
peaks = {"Sunday" => [], "Monday" => [], "Tuesday" => [], "Wednesday" => [],
"Thursday" => [], "Friday" => [], "Saturday" => []}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letters(id, form_letter)

  #putting these below the binding since they're not used in the letter...yet
  phone = clean_phonenumber(row[:homephone])
  peaks[get_regday(row[:regdate])] << get_reghour(row[:regdate])
end

peaks.keys.each do |day|
  puts "#{day}: #{peaks[day].sort!.join(", ")}"
end
#most people registered on Wednesdays (6/19), Thursdays (5/19), and Sundays (4/19)
#no super strong hourly pattern, but almost no one registers in the early morning (before 10:00)