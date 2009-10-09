class Gemcutter
  if Rails.env.development? || Rails.env.test?
    include Vault::FS
  else
    include Vault::S3
  end

  attr_reader :user, :spec, :message, :code, :rubygem, :body, :version, :version_id, :subdomain

  def initialize(user, body, subdomain = "gemcutter")
    @user = user
    @body = StringIO.new(body.read)
    find_subdomain(subdomain)
  end

  def process
    pull_spec and find_rubygem and authorize and save
  end

  def authorize
    user.rubyforge_importer? or
    rubygem.pushable? or
    rubygem.owned_by?(user) or
    subdomain.try(:belongs_to?, user) or
    notify("You do not have permission to push to this gem.", 403)
  end

  def save
    if update
      write_gem
      @version_id = self.version.id
      Delayed::Job.enqueue self
      notify("Successfully registered gem: #{self.version.to_title}", 200)
    else
      notify("There was a problem saving your gem: #{rubygem.errors.full_messages}", 403)
    end
  end

  def notify(message, code)
    @message = message
    @code    = code
    false
  end

  def update
    Rubygem.transaction do
      rubygem.build_ownership(user) unless user.try(:rubyforge_importer?)
      rubygem.save!
      @version = rubygem.update_attributes_from_gem_specification!(spec)
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::Rollback
    false
  end

  def pull_spec
    begin
      format = Gem::Format.from_io(self.body)
      @spec = format.spec
    rescue Exception => e
      notify("Gemcutter cannot process this gem.\n" + 
             "Please try rebuilding it and installing it locally to make sure it's valid.\n" +
             "Error:\n#{e.message}\n#{e.backtrace.join("\n")}", 422)
    end
  end

  def find_rubygem
    @rubygem = Rubygem.find_or_initialize_by_name_and_subdomain_id(
      self.spec.name,
      self.subdomain.try(:id)
    )
  end

  def find_subdomain(name)
    return if name == 'gemcutter'
    @subdomain = Subdomain.find_or_create_by_name(name)
    @subdomain.users << @user if @subdomain.users.count.zero?
  end

  def self.server_path(*more)
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'server', *more))
  end

  # Overridden so we don't get megabytes of the raw data printing out
  def inspect
    attrs = [:@rubygem, :@user, :@message, :@code].map { |attr| "#{attr}=#{instance_variable_get(attr) || 'nil'}" }
    "<Gemcutter #{attrs.join(' ')}>"
  end

  def self.indexer
    indexer = Gem::Indexer.new(Gemcutter.server_path, :build_legacy => false)
    def indexer.say(message) end
    indexer
  end
end
