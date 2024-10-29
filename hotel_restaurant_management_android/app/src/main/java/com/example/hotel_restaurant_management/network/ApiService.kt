package com.example.hotel_restaurant_management.network

import retrofit2.Call
import retrofit2.http.GET

interface ApiService {
    @GET("api/hotel/rooms")
    fun getRooms(): Call<List<Room>>
}
