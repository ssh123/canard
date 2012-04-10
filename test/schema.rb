ActiveRecord::Schema.define :version => 0 do

  create_table :users, :force => true do |t|
    t.string     :roles_mask
  end
  create_table :user_without_roles, :force => true do |t|
    t.string     :roles_mask
  end
  create_table :user_without_role_masks, :force => true do |t|
  end

end
