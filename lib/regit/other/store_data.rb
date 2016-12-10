module Regit

  module StoreData
    # Serializes an object and saves it to file.
    def save_to_file(file, object)
      File.open(file, 'w') do |f|
        f.write YAML.dump(object)
      end
    end

    # Loads yaml from file or returns an empty hash if file doesn't exist.
    def load_file(file)
      return YAML.load_file(file) if File.exist?(file)
      {}
    end
  end
end