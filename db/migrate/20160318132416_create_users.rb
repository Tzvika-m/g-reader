class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :uid
      t.string :name
      t.string :access_token
      t.string :refresh_token
      t.datetime :token_expires_at

      t.timestamps null: false
    end
  end
end
