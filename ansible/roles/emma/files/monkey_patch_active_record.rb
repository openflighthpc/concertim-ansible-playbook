require 'active_record/connection_adapters/postgresql_adapter'

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def set_standard_conforming_strings
    # Monkey patched to use 'warning' instead of 'panic'
    old, self.client_min_messages = client_min_messages, 'warning'
    execute('SET standard_conforming_strings = on', 'SCHEMA') rescue nil
  ensure
    self.client_min_messages = old
  end
end
