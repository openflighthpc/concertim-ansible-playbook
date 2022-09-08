require 'active_record/connection_adapters/postgresql_adapter'

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  # Does PostgreSQL support standard conforming strings?
  def supports_standard_conforming_strings?                                             
    # Temporarily set the client message level above error to prevent unintentional
    # error messages in the logs when working on a PostgreSQL database server that
    # does not support standard conforming strings.
    client_min_messages_old = client_min_messages                                
    # Monkey patched to use 'warning' instead of 'panic'
    self.client_min_messages = 'warning'

    # postgres-pr does not raise an exception when client_min_messages is set higher
    # than error and "SHOW standard_conforming_strings" fails, but returns an empty
    # PGresult instead.
    has_support = execute('SHOW standard_conforming_strings')[0][0] rescue false
    self.client_min_messages = client_min_messages_old
    has_support
  end
end
