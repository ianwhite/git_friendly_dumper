class CreateFirsts < ActiveRecord::Migration
  def self.up
    create_table :firsts do |t|
      t.string :name
    end
  end
  
  def self.down
    drop_table :firsts
  end
end