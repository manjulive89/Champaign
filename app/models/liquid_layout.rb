class LiquidLayout < ActiveRecord::Base
  has_many :pages
  validates :title, presence: true, allow_blank: false
  validates :content, presence: true, allow_blank: false

  # Removing this validation... causing more trouble than it's worth.
  # There are no hard consequences if an unkown partial is added
  # to a liquid layout.
  #
  # A possible alternative is to provide a warning message when
  # a partial name is unknown.
  # 
  # validate :no_unknown_partials

  def partial_names
    LiquidTagFinder.new(content).partial_names
  end

  def partial_refs
    LiquidTagFinder.new(content).partial_refs
  end

  def no_unknown_partials
    LiquidPartial.missing_partials(partial_names).each do |name|
      errors.add :content, "includes unknown partial '#{name}'"
    end
  end

  class << self
    def default
      find_by(title: 'default')
    end
  end
end
