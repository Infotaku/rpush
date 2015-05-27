module Rpush
  module Daemon
    module Store
      class Cequel
        DEFAULT_MARK_OPTIONS = { persist: true }

        def app(app_id)
          Rpush::Client::Cequel::App.find(*app_id)
        end

        def all_apps
          Rpush::Client::Cequel::App.all
        end

        def deliverable_notifications(limit)
          relation = ready_for_delivery.limit(limit)
          claim_notifications(relation)
        end

        def mark_delivered(notification, time, opts = {})
          opts = DEFAULT_MARK_OPTIONS.dup.merge(opts)
          notification.delivered = true
          notification.delivered_at = time
          notification.save!(validate: false) if opts[:persist]
        end

        def mark_batch_delivered(notifications)
          now = Time.now
          ids = []
          notifications.each do |n|
            mark_delivered(n, now, persist: false)
            ids << n.id
          end

          mark_ids_delivered(ids)
        end

        def mark_failed(notification, code, description, time, opts = {})
          opts = DEFAULT_MARK_OPTIONS.dup.merge(opts)
          notification.delivered = false
          notification.delivered_at = nil
          notification.failed = true
          notification.failed_at = time
          notification.error_code = code
          notification.error_description = description
          notification.save!(validate: false) if opts[:persist]
        end

        def mark_batch_failed(notifications, code, description)
          now = Time.now
          ids = []
          notifications.each do |n|
            mark_failed(n, code, description, now, persist: false)
            ids << n.id
          end

          mark_ids_failed(ids, code, description, now)
        end

        def mark_ids_failed(ids, code, description, time)
          return if ids.empty?

          collections = get_notification_collections(ids)

          collections.each do |collection|
            collection.update_all(processing: false, delivered: false, delivered_at: nil, failed: true, failed_at: time, error_code: code, error_description: description)
          end
        end

        def mark_retryable(notification, deliver_after, opts = {})
          opts = DEFAULT_MARK_OPTIONS.dup.merge(opts)
          notification.delivered = false
          notification.delivered_at = nil
          notification.failed = false
          notification.failed_at = nil
          notification.retries += [deliver_after]
          notification.deliver_after = deliver_after

          return unless opts[:persist]

          notification.save!(validate: false)
        end

        def mark_batch_retryable(notifications, deliver_after)
          ids = []
          notifications.each do |n|
            mark_retryable(n, deliver_after, persist: false)
            ids << n.id
          end

          mark_ids_retryable(ids, deliver_after)
        end

        def mark_ids_retryable(ids, deliver_after)
          return if ids.empty?

          collections = get_notification_collections(ids)

          collections.each do |collection|
            Rpush::Client::Cequel::Notification.connection.batch do
              collection.update_all(processing: false, delivered: false, delivered_at: nil, failed: false, failed_at: nil, deliver_after: deliver_after)
              collection.set_add(retries: deliver_after)
            end
          end
        end

        def create_apns_feedback(failed_at, device_token, app)
          Rpush::Client::Cequel::Apns::Feedback.create!(failed_at: failed_at, device_token: device_token, app: app)
        end

        def create_gcm_notification(attrs, data, registration_ids, deliver_after, app) # rubocop:disable ParameterLists
          notification = Rpush::Client::Cequel::Gcm::Notification.new
          create_gcm_like_notification(notification, attrs, data, registration_ids, deliver_after, app)
        end

        def create_adm_notification(attrs, data, registration_ids, deliver_after, app) # rubocop:disable ParameterLists
          notification = Rpush::Client::Cequel::Adm::Notification.new
          create_gcm_like_notification(notification, attrs, data, registration_ids, deliver_after, app)
        end

        def update_app(app)
          app.save!
        end

        def update_notification(notification)
          notification.save!
        end

        def release_connection
        end

        def reopen_log
        end

        def pending_delivery_count
          ready_for_delivery.count
        end

        def translate_integer_notification_id(id)
          Rpush::Client::Cequel::Notification.find_by_integer_id(id).id
        end

        private

        def mark_ids_delivered(ids)
          return if ids.empty?

          collections = get_notification_collections(ids)

          collections.each do |collection|
            collection.update_all(processing: false, delivered: true, delivered_at: now)
          end
        end

        def get_notification_collections(ids)
          # Assuming from Rpush::Daemon::AppRunner that any batch always comes from a single app
          app_name, app_env, app_service = ids.first.slice(0..2)

          # Notification id is : app_name, app_env, app_service, message_id, delivery_id
          by_message_ids = ids.group_by(&:fourth)

          by_message_ids.map do |message_id, grouped_ids|
            Rpush::Client::Cequel::Notification[app_name][app_env][app_service][message_id].values_at(grouped_ids)
          end
        end

        def ready_for_delivery
          # TODO (cequel-client) : transform for Cequel
          Rpush::Client::Cequel::Notification.where(processing: false, delivered: false, failed: false).or({ deliver_after: nil }, :deliver_after.lt => Time.now)
        end

        def claim_notifications(relation)
          # TODO (cequel-client) : transform for Cequel
          ids = relation.map(:id)

          Rpush::Client::Cequel::Notification.connection.batch do

          end
          relation.where('$isolated' => 1).in(id: ids).update_all(processing: true, processing_pid: Process.pid)
          Rpush::Client::Cequel::Notification.where(processing: true, processing_pid: Process.pid).in(id: ids).asc('created_at')
        end

        def create_gcm_like_notification(notification, attrs, data, registration_ids, deliver_after, app) # rubocop:disable ParameterLists
          notification.assign_attributes(attrs)
          notification.data = data
          notification.registration_ids = registration_ids
          notification.deliver_after = deliver_after
          notification.app = app
          notification.save!
          notification
        end
      end
    end
  end
end

Rpush::Daemon::Store::Interface.check(Rpush::Daemon::Store::Cequel)
