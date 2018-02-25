require 'rails_helper'

describe Trip, type: :model do

  describe "validations" do
    it "should not accepts decimal price" do
      trip = Trip.new(price: 1.23)
      expect(trip).to_not be_valid
      expect(trip.errors[:price].any?).to be true
    end

    it "should accepts rounded price" do
      trip = Trip.new(price: 0)
      expect(trip.errors[:price].empty?).to be true
    end
  end

  describe "scopes" do

    before(:each) do
      city = City.create!

      @trip = Trip.create!(
        departure_date: Time.zone.today,
        departure_time: Time.now,
        price: 12,
        title: 'M',
        name: 'John',
        email: 'yolo@example.com',
        seats: 2,
        comfort: 'comfort',

        points: [
          Point.new(kind: 'From', lat: 1.23, lon: 1.24, city: city),
          Point.new(kind: 'Step', lat: 1.24, lon: 1.25, city: city, rank: 1, price: 4),
          Point.new(kind: 'Step', lat: 1.25, lon: 1.26, city: city, rank: 2, price: 5),
          Point.new(kind: 'To', lat: 1.83, lon: 1.84, city: city)
        ]
      )
    end

    describe '.from_to' do
      it "should return each matching Trip only one time and with the nearest points" do
        results = Trip.from_to(1.24, 1.23, 1.25, 1.24)
                      .where(id: @trip.id)

        expect(results).to be_a ActiveRecord::Relation
        expect(results.map { |result|
          result.attributes.slice(
            'id', 'price',
            'point_a_id', 'point_a_price',
            'point_b_id', 'point_b_price'
          )
        }).to eq [{
          'id' => @trip.id,
          'price' => @trip.price,
          'point_a_id' => @trip.points[0].id,
          'point_a_price' => @trip.points[0].price,
          'point_b_id' => @trip.points[1].id,
          'point_b_price' => @trip.points[1].price
        }]
      end
    end

    describe '.from_only' do
      # TODO: only one time and with the nearest from point
      it "should return each matching Trip multiple time with different from point" do
        results = Trip.from_only(1.25, 1.24)
                      .where(id: @trip.id)

        expect(results).to be_a ActiveRecord::Relation
        expect(results.map { |result|
          result.attributes.slice(
            'id', 'price',
            'point_a_id', 'point_a_price'
          )
        }).to eq [{
          'id' => @trip.id,
          'price' => @trip.price,
          'point_a_id' => @trip.points[1].id,
          'point_a_price' => @trip.points[1].price
        }]
      end
    end

    describe '.to_only' do
      it "should return each matching Trip only one time with different to point" do
        results = Trip.to_only(1.26, 1.25)
                      .where(id: @trip.id)

        expect(results).to be_a ActiveRecord::Relation
        expect(results.map { |result|
          result.attributes.slice(
            'id', 'price',
            'point_b_id', 'point_b_price'
          )
        }).to eq [{
          'id' => @trip.id,
          'price' => @trip.price,
          'point_b_id' => @trip.points[2].id,
          'point_b_price' => @trip.points[2].price
        }]
      end
    end

  end

  describe '#clone_as_back_trip' do
    it "should work as expected with steps prices" do
      cities = create_list(:city, 5)
      trip = Trip.new(price: 100)
      trip.points.build(rank: 0, city: cities[0], kind: 'From')
      trip.points.build(rank: 1, city: cities[1], kind: 'Step', price: 10)
      trip.points.build(rank: 2, city: cities[2], kind: 'Step', price: 40)
      trip.points.build(rank: 3, city: cities[3], kind: 'Step', price: 65)
      trip.points.build(rank: 4, city: cities[5], kind: 'To')

      clone_trip = trip.clone_as_back_trip

      expect(clone_trip.price).to eq trip.price
      expect(clone_trip.points[0].attributes).to include(
        'rank' => 0, 'kind' => 'From', 'city' => cities[4], 'price' => nil)
      expect(clone_trip.points[1].attributes).to include(
        'rank' => 1, 'kind' => 'Step', 'city' => cities[3], 'price' => 35)
      expect(clone_trip.points[2].attributes).to include(
        'rank' => 2, 'kind' => 'Step', 'city' => cities[2], 'price' => 60)
      expect(clone_trip.points[3].attributes).to include(
        'rank' => 3, 'kind' => 'Step', 'city' => cities[1], 'price' => 90)
      expect(clone_trip.points[4].attributes).to include(
        'rank' => 4, 'kind' => 'To', 'city' => cities[0], 'price' => nil)
    end
  end

end
