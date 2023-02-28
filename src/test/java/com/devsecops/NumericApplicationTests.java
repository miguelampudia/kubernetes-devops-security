package com.devsecops;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

public class NumericApplicationTests {

	private MockMvc mockMvc;

	@BeforeEach
	void setUp() {
		this.mockMvc = MockMvcBuilders.standaloneSetup(new NumericController()).build();
	}

	@Test
	public void smallerThanOrEqualToFiftyMessage() throws Exception {
		this.mockMvc.perform(get("/compare/50")).andDo(print()).andExpect(status().isOk())
				.andExpect(content().string("Smaller than or equal Oto 50"));
	}

	@Test
	public void greaterThanFiftyMessage() throws Exception {
		this.mockMvc.perform(get("/compare/51")).andDo(print()).andExpect(status().isOk())
				.andExpect(content().string("Greater than 50"));
	}

	@Test
	public void welcomeMessage() throws Exception {
		this.mockMvc.perform(get("/")).andDo(print()).andExpect(status().isOk())
				.andExpect(content().string("Kubernetes DevSecOps"));
	}

}