class CreateFreeIp < ActiveRecord::Migration[6.0]
  def change
    create_table :free_ips do |t|
      t.boolean :active,      default: false
      t.boolean :routable,    default: false
      t.string  :version,     default: 'ipv4'
      t.string  :ip
      t.string  :description, default: ''
      t.timestamps
    end
  end
end
