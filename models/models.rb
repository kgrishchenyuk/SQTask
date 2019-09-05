class User < ActiveRecord::Base
    include ActiveModel::Serializers::Xml
    has_secure_password

    has_many :inventories
    has_many :lots

    validates :username, :password, :level, :balance, presence: true
    validates :username, uniqueness: true
end 

class Item < ActiveRecord::Base
    include ActiveModel::Serializers::Xml

    has_many :inventories
    has_many :lots

    validates :name, uniqueness: true
end

class Inventory < ActiveRecord::Base
    belongs_to :user
    belongs_to :item

    validates :user_id, uniqueness: {scope: :item_id}
end

class Lot < ActiveRecord::Base
    include ActiveModel::Serializers::Xml

    belongs_to :user
    belongs_to :item

    validates :user_id, uniqueness: {scope: :item_id}


    scope :price, -> (price) {where ("lots.price = ?"), price}
    scope :price_greater, -> (price_gt) {where ("lots.price > ?"), price_gt}
    scope :price_lower, -> (price_lt) {where ("lots.price < ?"), price_lt}
    scope :amount, -> (amount) {where ("lots.amount = ?"), amount}
    scope :amount_greater, -> (amount_gt) {where ("lots.amount > ?"), amount_gt}
    scope :amount_lower, -> (amount_lt) {where ("lots.amount < ?"), amount_lt}

    def self.filter (params)
        lots = Lot.all
        lots = lots.price(params[:price]) if params[:price].present?
        lots = lots.price_greater(params[:price_gt]) if params[:price_gt].present?
        lots = lots.price_lower(params[:price_lt]) if params[:price_lt].present?
        lots = lots.amount(params[:amount]) if params[:amount].present?
        lots = lots.amount_greater(params[:amount_gt]) if params[:amount_gt].present?
        lots = lots.amount_lower(params[:amount_lt]) if params[:amount_lt].present?
        return lots
    end
end