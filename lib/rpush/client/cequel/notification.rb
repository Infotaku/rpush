module Rpush
  module Client
    module Cequel
      class Notification
        include Cequel::Record
        include Rpush::MultiJsonHelper
        include Rpush::Client::ActiveModel::Notification

        belongs_to :app, class_name: 'Rpush::Client::Cequel::App', partition: true

        key :message_id, :uuid, partition: true
        key :delivery_id, :timeuuid, order: :desc

        column :badge, :int
        column :device_token, :text
        column :sound, :text, default: 'default'
        column :alert, :text
        column :data, :text
        column :expiry, :int, default: 1.day.to_i
        column :delivered, :boolean, default: false
        column :delivered_at, :timestamp
        column :processing, :boolean, default: false
        column :failed, :boolean, default: false
        column :failed_at, :timestamp
        column :fail_after, :timestamp
        column :error_code, :int
        column :error_description, :text
        column :deliver_after, :timestamp
        column :alert_is_json, :boolean
        column :collapse_key, :text
        column :delay_while_idle, :boolean
        column :uri, :text
        column :priority, :int
        column :url_args, :text
        column :category, :text

        column :integer_id, :int, index: true # TODO (cequel-client) : generate a unique 32bits integer (scoped at app level)

        timestamps

        set :registration_ids, :text
        set :retries, :timestamp

        def id
          app_id + [message_id, delivery_id]
        end

        def app_id
          [app_name, app_environement, app_service]
        end

        # trying to work around the non-atomic integer incrementation from cequel
        def retries(raw = false)
          raw ? super() : super().size
        end

        def registration_ids=(ids)
          ids = [ids] if ids && !ids.is_a?(Array)
          super
        end

        def data=(attrs)
          return unless attrs
          fail ArgumentError, "must be a Hash" unless attrs.is_a?(Hash)
          write_attribute(:data, multi_json_dump(attrs.merge(data || {})))
        end

        def data
          multi_json_load(read_attribute(:data)) if read_attribute(:data)
        end

        def url_args=(array)
          return unless array
          fail ArgumentError, "must be an Array" unless array.is_a?(Array)
          write_attribute(:url_args, multi_json_dump(array))
        end

        def url_args
          multi_json_load(read_attribute(:url_args)) if read_attribute(:url_args)
        end
      end
    end
  end
end
