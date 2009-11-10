class CreateGoogledocsProjects < ActiveRecord::Migration
  def self.up
    create_table :googledocs_projects do |t|
      t.column :project_id, :integer
      t.column :project_folder, :string
    end
  end

  def self.down
    drop_table :googledocs_projects
  end
end
