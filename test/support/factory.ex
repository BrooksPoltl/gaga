defmodule Gaga.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: Gaga.Repo

  def user_factory do
    %Gaga.Accounts.User{
      name: sequence(:name, &"User #(#{&1})")
    }
  end

  def room_factory do
    %Gaga.Poker.Room{
      name: sequence(:name, &"Room #(#{&1})"),
      user: build(:user)
    }
  end

  def room_user_factory(attrs) do
    user_id = Map.get(attrs, :user_id)
    room_id = Map.get(attrs, :room_id)

    %Gaga.Poker.RoomUser{
      user_id: user_id,
      room_id: room_id
    }
  end

  # def article_factory do
  #   title = sequence(:title, &"Use ExMachina! (Part #{&1})")
  #   # derived attribute
  #   slug = MyApp.Article.title_to_slug(title)

  #   %MyApp.Article{
  #     title: title,
  #     slug: slug,
  #     # associations are inserted when you call `insert`
  #     author: build(:user)
  #   }
  # end

  # # derived factory
  # def featured_article_factory do
  #   struct!(
  #     article_factory(),
  #     %{
  #       featured: true
  #     }
  #   )
  # end

  # def comment_factory do
  #   %MyApp.Comment{
  #     text: "It's great!",
  #     article: build(:article)
  #   }
  # end
end
