module Rpush
  module Client
    module Cequel
      class App
        include Cequel::Record

        has_many :notifications, class_name: 'Rpush::Client::Cequel::Notification', dependent: :destroy

        key :name,              :text, partition: true
        key :environment,       :text, partition: true
        key :service,           :text, default: :service_name, order: :asc

        column :certificate,    :text
        column :password,       :text
        column :connections,    :int, default: 1
        column :auth_key,       :text
        column :client_id,      :text
        column :client_secret,  :text

        def id
          [name, environment, service]
        end

        validates :name, presence: true
        validates_numericality_of :connections, greater_than: 0, only_integer: true
      end
    end
  end
end
