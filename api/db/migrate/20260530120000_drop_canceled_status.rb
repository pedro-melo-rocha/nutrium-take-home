class DropCanceledStatus < ActiveRecord::Migration[7.2]
  def up
    execute "UPDATE appointment_requests SET status = 'rejected' WHERE status = 'canceled'"

    remove_check_constraint :appointment_requests, name: "status_in_enum"
    add_check_constraint :appointment_requests,
      "status IN ('pending', 'accepted', 'rejected')",
      name: "status_in_enum"
  end

  def down
    remove_check_constraint :appointment_requests, name: "status_in_enum"
    add_check_constraint :appointment_requests,
      "status IN ('pending', 'accepted', 'rejected', 'canceled')",
      name: "status_in_enum"
  end
end
