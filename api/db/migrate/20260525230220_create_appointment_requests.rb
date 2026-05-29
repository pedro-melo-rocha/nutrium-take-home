class CreateAppointmentRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :appointment_requests do |t|
      t.references :nutritionist, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.string :guest_name, null: false
      t.string :guest_email, null: false
      t.column :starts_at, :timestamptz, null: false
      t.column :ends_at, :timestamptz, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :appointment_requests, :guest_email
    add_index :appointment_requests, [ :nutritionist_id, :status ]
    add_check_constraint :appointment_requests,
      "status IN ('pending', 'accepted', 'rejected', 'canceled')",
      name: "status_in_enum"
    add_check_constraint :appointment_requests,
      "ends_at > starts_at",
      name: "ends_after_starts"
  end
end
