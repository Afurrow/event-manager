require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end


def clean_phone_num(phone_num)
    phone_num = phone_num.to_s.scan(/\d/).join('')
    phone_num_length = phone_num.length()
    if phone_num_length < 10 or phone_num_length > 11 or (phone_num_length == 11 and not phone_num.start_with? '1')
        "Inaccurate phone number: #{phone_num}"
    elsif phone_num_length == 11 and phone_num.start_with? '1'
        phone_num = phone_num[1..11]
    else 
        phone_num
    end 
end 


def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin 
        legislators = civic_info.representative_info_by_address(
            address: zipcode, 
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end 
end 


def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exists?('output')
    file_name = "output/thanks_#{id}.html"
    File.open(file_name, 'w') do |file|
        file.puts form_letter
    end
end


def get_unique_count(dict, val)
    if dict.member? val
        dict[val] = dict[val]+1
    else 
        dict[val] = 1
    end
end


puts 'Event Manager Initialized!'

f_name = 'event_attendees.csv'
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

if File.exists? f_name
    contents = CSV.open(f_name, headers: true, header_converters: :symbol)
    hour_count = {}
    day_count = {}
    contents.each do |row|
        id = row[0]
        name = row[:first_name]
        zipcode = clean_zipcode(row[:zipcode])
        phone_num = clean_phone_num(row[:homephone])
        reg_date = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')
        get_unique_count(hour_count, reg_date.hour) 
        get_unique_count(day_count, reg_date.strftime('%a'))
        legislators = legislators_by_zipcode(zipcode)
        form_letter = erb_template.result(binding)
        save_thank_you_letter(id, form_letter)
    end
end

puts"Respondents registered in the following hours: #{hour_count.sort_by { |key, val| val }.reverse }"
puts"Respondents registered on the following days: #{day_count.sort_by { |key, val| val }.reverse}"
