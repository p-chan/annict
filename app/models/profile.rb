# frozen_string_literal: true
# == Schema Information
#
# Table name: profiles
#
#  id                                  :integer          not null, primary key
#  user_id                             :integer          not null
#  name                                :string(510)      default(""), not null
#  description                         :string(510)      default(""), not null
#  created_at                          :datetime
#  updated_at                          :datetime
#  background_image_animated           :boolean          default(FALSE), not null
#  tombo_avatar_file_name              :string
#  tombo_avatar_content_type           :string
#  tombo_avatar_file_size              :integer
#  tombo_avatar_updated_at             :datetime
#  tombo_background_image_file_name    :string
#  tombo_background_image_content_type :string
#  tombo_background_image_file_size    :integer
#  tombo_background_image_updated_at   :datetime
#  url                                 :string
#  image_data                          :text
#  background_image_data               :text
#
# Indexes
#
#  profiles_user_id_idx  (user_id)
#  profiles_user_id_key  (user_id) UNIQUE
#

class Profile < ApplicationRecord
  include ProfileImageUploader::Attachment.new(:image)
  include ProfileImageUploader::Attachment.new(:background_image)
  include ImageUploadable

  belongs_to :user

  validates :description, length: { maximum: 150 }
  validates :name, presence: true
  validates :url, url: { allow_blank: true }

  before_save :check_animated_gif

  def description=(description)
    value = description.present? ? description.truncate(150) : ""
    write_attribute(:description, value)
  end

  private

  def check_animated_gif
    if background_image_data_changed?
      file = uploaded_file(:background_image, size: :original)
      data = Rails.env.test? ? file.to_io : file.url
      image = MiniMagick::Image.open(data)
      self.background_image_animated = (image.frames.length > 1)
    end

    self
  end
end
