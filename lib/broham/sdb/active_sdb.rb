class RightAws::ActiveSdb::Base

  # Store in-memory attributes to SDB.
  # Replaces the attributes values already stored at SDB by in-memory data.
  # Returns a hash of stored attributes.
  #
  #  sandy = Client.new(:name => 'Sandy')  #=> #<Client:0xb775a7a8 @attributes={"name"=>["Sandy"]}, @new_record=true>
  #  sandy['toys'] = 'boys'
  #  sandy.put
  #  sandy['toys'] = 'patchwork'
  #  sandy.put
  #  sandy['toys'] = 'kids'
  #  sandy.put
  #  puts sandy.attributes.inspect         #=> {"name"=>["Sandy"], "id"=>"b2832ce2-e461-11dc-b13c-001bfc466dd7", "toys"=>["kids"]}
  #  sandy.reload                          #=> {"name"=>["Sandy"], "id"=>"b2832ce2-e461-11dc-b13c-001bfc466dd7", "toys"=>["kids"]}
  #
  # compare to +put+ method
  def save expected_attributes={ }
    @attributes = uniq_values(@attributes)
    prepare_for_update
    connection.put_attributes(domain, id, @attributes, :replace, expected_attributes)
    mark_as_old
    @attributes
  end

  def save_if expected_attributes={ }
    begin
      save expected_attributes
    rescue RightAws::AwsError => e
      false
    end
  end

  # Replaces the attributes at SDB by the given values.
  # +Attrs+ is a hash: { attribute1 => values1, ..., attributeN => valuesN }.
  # The other in-memory attributes are not being saved.
  # Returns a hash of stored attributes.
  #
  # see +save+ method
  def save_attributes(attrs, expected_attributes={})
    prepare_for_update
    attrs = uniq_values(attrs)
    # if 'id' is present in attrs hash then replace internal 'id' attribute
    unless attrs['id'].blank?
      @attributes['id'] = attrs['id']
    else
      attrs['id'] = id
    end
    connection.put_attributes(domain, id, attrs, :replace, expected_attributes) unless attrs.blank?
    attrs.each { |attribute, values| attrs[attribute] = values }
    mark_as_old
    attrs
  end

end
