class AddAppointmentRequestConstraints < ActiveRecord::Migration[7.2]
  def up
    # One-pending-per-guest race-safety net.
    # The app-side flow invalidates prior pending rows in a transaction before
    # inserting the new one; this index catches the race where two concurrent
    # submits from the same email arrive simultaneously.
    add_index :appointment_requests,
      :guest_email,
      unique: true,
      where: "status = 'pending'",
      name: "index_appointment_requests_unique_pending_per_guest"

    # Overlap guard for accepted appointments. GiST exclusion: no two accepted
    # requests for the same nutritionist can have overlapping time ranges.
    # Requires the btree_gist extension (enabled in prior migration).
    # tstzrange uses '[)' inclusivity by default (inclusive start, exclusive end).
    execute <<~SQL
      ALTER TABLE appointment_requests
      ADD CONSTRAINT no_overlapping_accepted
      EXCLUDE USING gist (
        nutritionist_id WITH =,
        tstzrange(starts_at, ends_at) WITH &&
      )
      WHERE (status = 'accepted')
    SQL
  end

  def down
    execute "ALTER TABLE appointment_requests DROP CONSTRAINT IF EXISTS no_overlapping_accepted"
    remove_index :appointment_requests, name: "index_appointment_requests_unique_pending_per_guest"
  end
end
