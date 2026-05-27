class EnableBtreeGistExtension < ActiveRecord::Migration[7.2]
  def change
    enable_extension "btree_gist"
  end
end
