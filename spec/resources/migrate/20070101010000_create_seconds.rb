class CreateSeconds < ActiveRecord::Migration
  def self.up
    create_table :seconds do |t|
      t.string :name
    end
  end
  
  def self.down
    drop_table :seconds
  end
end