class CreateCategoryBlogs < ActiveRecord::Migration[8.1]
  def change
    create_table :category_blogs do |t|
      t.references :category, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true

      t.timestamps
    end
  end
end
