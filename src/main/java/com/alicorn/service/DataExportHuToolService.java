package com.alicorn.service;

import cn.hutool.core.io.FileUtil;
import com.alicorn.util.MyBatisUtil;
import org.apache.ibatis.session.SqlSession;

import java.io.BufferedWriter;
import java.io.File;
import java.util.List;
import java.util.Map;

public class DataExportHuToolService {
    public void exportData(String tableName, String filePath) {
        try (SqlSession session = MyBatisUtil.getSqlSessionFactory().openSession()) {

            List<Map<String, Object>> results = session.selectList("GenericMapper.selectAll", tableName);

            File file = FileUtil.file(filePath);
            try (BufferedWriter writer = FileUtil.getWriter(file, "UTF-8", false)) {
                if (!results.isEmpty()) {
                    String header = String.join(",", results.get(0).keySet());
                    writer.write(header);
                    writer.newLine();

                    for (Map<String, Object> row : results) {
                        String line = String.join(",", row.values().stream()
                                .map(value -> value == null ? "" : value.toString())
                                .toArray(String[]::new));
                        writer.write(line);
                        writer.newLine();
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
