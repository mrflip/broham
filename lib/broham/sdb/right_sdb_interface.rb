class RightAws::SdbInterface < RightAws::RightAwsBase

  # Prepare attributes for putting.
  # (used by put_attributes)
  def pack_attributes(items_or_attributes, replace = false, batch = false, expected_attributes = {}) #:nodoc:
    if batch
      index = 0
      items_or_attributes.inject({}){|result, (item_name, attributes)|
        item_prefix = "Item.#{index}."
        result["#{item_prefix}ItemName"] = item_name.to_s
        result.merge!(
          pack_single_item_attributes(attributes, replace, item_prefix, expected_attributes))
        index += 1
        result
      }
    else
      pack_single_item_attributes(items_or_attributes, replace)
    end
  end

  def pack_single_item_attributes(attributes, replace, prefix = "", expected_attributes={})
    result = {}
    if attributes
      idx = 0
      skip_values = attributes.is_a?(Array)
      attributes.each do |attribute, values|
        # set replacement attribute
        result["#{prefix}Attribute.#{idx}.Replace"] = 'true' if replace

        # set expected attribute
        expected_attributes = expected_attributes.to_mash
        if expected_attributes.include?(attribute)
          result["Expected.#{idx}.Name"] = attribute
          if expected_attributes[attribute].nil?
            result["Expected.#{idx}.Exists"] = 'false'
          else
            result["Expected.#{idx}.Value"] = expected_attributes[attribute]
          end
        end

        # pack Name/Value
        unless values.nil?
          # Array(values) does not work here:
          #  - Array('') => [] but we wanna get here ['']
          [values].flatten.each do |value|
            result["#{prefix}Attribute.#{idx}.Name"]  = attribute
            result["#{prefix}Attribute.#{idx}.Value"] = ruby_to_sdb(value) unless skip_values
            idx += 1
          end
        else
          result["#{prefix}Attribute.#{idx}.Name"] = attribute
          result["#{prefix}Attribute.#{idx}.Value"] = ruby_to_sdb(nil) unless skip_values
          idx += 1
        end
      end
    end
    result
  end

  # Add/Replace item attributes.
  #
  # Params:
  #  domain_name = DomainName
  #  item_name   = ItemName
  #  attributes  = {
  #    'nameA' => [valueA1,..., valueAN],
  #    ...
  #    'nameZ' => [valueZ1,..., valueZN]
  #  }
  #  replace = :replace | any other value to skip replacement
  #
  # Returns a hash: { :box_usage, :request_id } on success or an exception on error.
  # (Amazon raises no errors if the attribute was not overridden, as when the :replace param is unset).
  #
  # Example:
  #
  #  sdb = RightAws::SdbInterface.new
  #  sdb.create_domain 'family'
  #
  #  attributes = {}
  #  # create attributes for Jon and Silvia
  #  attributes['Jon']    = %w{ car beer }
  #  attributes['Silvia'] = %w{ beetle rolling_pin kids }
  #  sdb.put_attributes 'family', 'toys', attributes   #=> ok
  #  # now: Jon=>[car, beer], Silvia=>[beetle, rolling_pin, kids]
  #
  #  # add attributes to Jon
  #  attributes.delete('Silvia')
  #  attributes['Jon'] = %w{ girls pub }
  #  sdb.put_attributes 'family', 'toys', attributes   #=> ok
  #  # now: Jon=>[car, beer, girls, pub], Silvia=>[beetle, rolling_pin, kids]
  #
  #  # replace attributes for Jon and add to a cat (the cat had no attributes before)
  #  attributes['Jon'] = %w{ vacuum_cleaner hammer spade }
  #  attributes['cat'] = %w{ mouse clew Jons_socks }
  #  sdb.put_attributes 'family', 'toys', attributes, :replace #=> ok
  #  # now: Jon=>[vacuum_cleaner, hammer, spade], Silvia=>[beetle, rolling_pin, kids], cat=>[mouse, clew, Jons_socks]
  #
  # see: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/SDB_API_PutAttributes.html
  #
  def put_attributes(domain_name, item_name, attributes, replace = false, expected_attributes = {})
    begin
      params = { 'DomainName' => domain_name,
        'ItemName'   => item_name }.merge(pack_attributes(attributes, replace, false, expected_attributes))
      link = generate_request("PutAttributes", params)
      request_info( link, QSdbSimpleParser.new )
    rescue RightAws::AwsError => e
      # Don't sever the connection on a conditional put failure.
      (e.to_s =~ /ConditionalCheckFailed:/) ? raise : on_exception()
    rescue Exception
      on_exception
    end
  end

  # Delete value, attribute or item.
  #
  # Example:
  #  # delete 'vodka' and 'girls' from 'Jon' and 'mice' from 'cat'.
  #  sdb.delete_attributes 'family', 'toys', { 'Jon' => ['vodka', 'girls'], 'cat' => ['mice'] }
  #
  #  # delete the all the values from attributes (i.e. delete the attributes)
  #  sdb.delete_attributes 'family', 'toys', { 'Jon' => [], 'cat' => [] }
  #  # or
  #  sdb.delete_attributes 'family', 'toys', [ 'Jon', 'cat' ]
  #
  #  # delete all the attributes from item 'toys' (i.e. delete the item)
  #  sdb.delete_attributes 'family', 'toys'
  #
  # see http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/SDB_API_DeleteAttributes.html
  #
  def delete_attributes(domain_name, item_name, attributes = nil, expected_attributes = {})
    params = { 'DomainName' => domain_name,
      'ItemName'   => item_name }.merge(pack_attributes(attributes, false, false, expected_attributes))
    link = generate_request("DeleteAttributes", params)
    request_info( link, QSdbSimpleParser.new )
  rescue Exception
    on_exception
  end
end


