require 'spec_helper'

describe ServiceInstance do
  let(:id) { '88f6fa22-c8b7-4cdc-be3a-dc09ea7734db' }
  let(:database) { 'cf_88f6fa22_c8b7_4cdc_be3a_dc09ea7734db' }
  let(:instance) { ServiceInstance.new(id: id) }

  describe '.find_by_id' do
    context 'when the database exists' do
      before { connection.execute("CREATE DATABASE `#{database}`") }
      after { connection.execute("DROP DATABASE IF EXISTS `#{database}`") }

      it 'returns the instance' do
        instance = ServiceInstance.find_by_id(id)
        expect(instance).to be_a(ServiceInstance)
        expect(instance.id).to eq(id)
      end
    end

    context 'when the database does not exist' do
      it 'returns nil' do
        instance = ServiceInstance.find_by_id(id)
        expect(instance).to be_nil
      end
    end
  end

  describe '.find' do
    context 'when the database exists' do
      before { connection.execute("CREATE DATABASE `#{database}`") }
      after { connection.execute("DROP DATABASE IF EXISTS `#{database}`") }

      it 'returns the instance' do
        instance = ServiceInstance.find(id)
        expect(instance).to be_a(ServiceInstance)
        expect(instance.id).to eq(id)
      end
    end

    context 'when the database does not exist' do
      it 'raises an error' do
        expect {
          ServiceInstance.find(id)
        }.to raise_error
      end
    end
  end

  describe '.exists?' do
    context 'when the database exists' do
      before { connection.execute("CREATE DATABASE `#{database}`") }
      after { connection.execute("DROP DATABASE IF EXISTS `#{database}`") }

      it 'returns true' do
        expect(ServiceInstance.exists?(id)).to eq(true)
      end
    end

    context 'when the database does not exist' do
      it 'returns false' do
        expect(ServiceInstance.exists?(id)).to eq(false)
      end
    end
  end

  describe '.get_number_of_existing_instances' do
    context 'when the database exists' do
      before { connection.execute("CREATE DATABASE `#{database}`") }
      after { connection.execute("DROP DATABASE IF EXISTS `#{database}`") }

      it 'returns the number of instances' do
        expect(ServiceInstance.get_number_of_existing_instances).to eq(1)
      end
    end

    context 'when the database does not exist' do
      it 'returns zero' do
        expect(ServiceInstance.get_number_of_existing_instances).to eq(0)
      end
    end
  end

  describe '#save' do
    let(:existing_database) { 'existing' }

    before { connection.execute("CREATE DATABASE IF NOT EXISTS `#{existing_database}`") }

    after do
      connection.execute("DROP DATABASE IF EXISTS `#{existing_database}`")
      connection.execute("DROP DATABASE IF EXISTS `#{database}`")
    end

    it 'creates the database' do
      expect {
        instance.save
      }.to change {
        connection.select("SHOW DATABASES LIKE '#{database}'").count
      }.from(0).to(1)
    end

    it 'avoids collisions with existing databases' do
      instance = ServiceInstance.new(id: existing_database)

      expect {
        instance.save
      }.to_not change {
        connection.select("SHOW DATABASES LIKE '#{id}'").count
      }.from(1)

      instance.destroy
    end
  end

  describe '#destroy' do
    let(:existing_database) { 'existing' }

    before { connection.execute("CREATE DATABASE IF NOT EXISTS `#{existing_database}`") }
    after { connection.execute("DROP DATABASE IF EXISTS `#{existing_database}`") }

    context 'when the database exists' do
      before { connection.execute("CREATE DATABASE IF NOT EXISTS `#{database}`") }
      after { connection.execute("DROP DATABASE IF EXISTS `#{database}`") }

      it 'drops the database' do
        expect {
          instance.destroy
        }.to change {
          connection.select("SHOW DATABASES LIKE '#{database}'").count
        }.from(1).to(0)
      end
    end

    context 'when the database does not exist' do
      it 'does not raise an error' do
        expect {
          instance.destroy
        }.to_not raise_error
      end
    end

    it 'avoids collisions with existing databases' do
      instance = ServiceInstance.new(id: existing_database)

      expect {
        instance.destroy
      }.to_not change {
        connection.select("SHOW DATABASES LIKE '#{id}'").count
      }.from(1)
    end
  end

  describe '#database' do
    it 'returns a namespaced, MySQL-safe database name from the id' do
      instance = ServiceInstance.new(id: '88f6fa22-c8b7-4cdc-be3a-dc09ea7734db')
      expect(instance.database).to eq('cf_88f6fa22_c8b7_4cdc_be3a_dc09ea7734db')
    end

    # Technically we should allow any kind of character in an id;
    # we don't absolutely know that ids are guids. But that would
    # require writing some escaping code.
    context 'when there are strange characters in the id' do
      let(:instance) { ServiceInstance.new(id: '!@\#$%^&*() ;') }

      it 'raises an error' do
        expect {
          instance.database
        }.to raise_error
      end
    end
  end

  describe '#to_json' do
    it 'is empty json' do
      hash = JSON.parse(instance.to_json)
      expect(hash).to eq({})
    end
  end
end
