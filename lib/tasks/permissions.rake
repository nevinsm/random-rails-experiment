namespace :permissions do
  desc "Load or update the permissions catalog from db/seeds/permissions.yml"
  task load: :environment do
    path = Rails.root.join("db", "seeds", "permissions.yml")
    unless File.exist?(path)
      puts "Permissions catalog not found at #{path}"
      exit 1
    end

    yaml = YAML.load_file(path)
    unless yaml.is_a?(Array)
      puts "Invalid YAML format: expected an array"
      exit 1
    end

    upserted = 0
    yaml.each do |attrs|
      key = attrs["key"] || attrs[:key]
      name = attrs["name"] || attrs[:name]
      description = attrs["description"] || attrs[:description]

      next unless key && name

      permission = Permission.find_or_initialize_by(key: key)
      permission.name = name
      permission.description = description
      if permission.changed?
        permission.save!
        upserted += 1
      end
    end

    puts "Permissions upserted: #{upserted}"
  end
end


