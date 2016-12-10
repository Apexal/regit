
module Regit
  module Database
    ActiveRecord::Base.establish_connection(  
      adapter: 'mysql2',  
      host: Regit::CONFIG.db[:host],  
      database: Regit::CONFIG.db[:database],
      username: Regit::CONFIG.db[:username],
      password: Regit::CONFIG.db[:password]
    )

    class School < ActiveRecord::Base
      has_many :students, inverse_of: :school
      has_many :courses, inverse_of: :school
    end

    class Student < ActiveRecord::Base
      belongs_to :school, inverse_of: :students
    end

    class Course < ActiveRecord::Base
      belongs_to :school, inverse_of: :courses
    end
  end
end