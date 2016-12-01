class CreateServers < ActiveRecord::Migration[5.0]
  def change
    create_table :servers do |t|
      t.string :hostname, null: false
      t.string :username
      t.integer :port
      t.belongs_to :user, index: true
      t.timestamps
    end
  end
end
